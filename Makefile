# Makefile for mail server setup
#
.PHONY: all bootstrap mailserver rebootstrap reset clean \
  edit edit_secrets redo save help

USER_VAR = deploy_user_name
VAR_FILE = group_vars/all/vars.yml
DEPLOY_USER = $(shell grep ${USER_VAR} ${VAR_FILE} >/dev/null 2>&1 | \
	awk -F: '{print $$2}')

ifeq "${DEPLOY_USER}" ""
DEPLOY_USER = deploy
endif

EDITOR ?= vi

all:
	@if [ ! -r ${VAR_FILE} ]; then \
		./bin/setup; \
		if [ $$? -ne 0 ]; then exit $$?; fi; \
		make bootstrap; \
	fi; \
	make mailserver

help:
	@echo "all (default) - bootstrap if needed, then deploy mailserver."
	@echo "bootstrap - run the bootstrap playbook as user root"
	@echo "mailserver - deploy mail server stack (as deploy user)"
	@echo "rebootstrap - run the bootstrap playbook as deploy user."
	@echo "reset - delete inventory and variables for a fresh start."
	@echo "clean - remove any *.retry files."
	@echo "edit - run EDITOR (default vi) on variables file."
	@echo "edit_secrets - decrypt, run EDITOR on secrets file, then encrypt."
	@echo "redo - re-run bootstrap and mailserver playbooks (as deploy user)"
	@echo "save - save variables and inventory in backup-YYYYMMDD-hhmm.tgz"
	@echo "help - print this message."

mailserver:
	@echo "Running playbooks using ${DEPLOY_USER} user"
	ansible-playbook -u ${DEPLOY_USER} mailserver.yml

# bootstrap sets up a secure debian server (the first time)
bootstrap:
	ansible-playbook -u root -k bootstrap.yml

# since root ssh logins are disabled, need to run this when boostrapping again
rebootstrap:
	ansible-playbook -u ${DEPLOY_USER} bootstrap.yml

redo: rebootstrap all

# GENERATED FILES
GEN = inventory group_vars .vault_pass.txt

# clean up and start over
reset:
	rm -rf ${GEN}
	touch .vault_pass.txt; chmod 600 .vault_pass.txt

# save the current set of variables and vault password
save:
	name=backup-`date +'%Y%m%d-%H%M'`.tar.gz; tar cvzf $$name ${GEN}

# simple cleanup of ansible cruft
clean:
	rm -rf *.retry

VARS_FILE = group_vars/all/vars.yml
edit:
	@if [ -r ${VARS_FILE} ]; then \
		${EDITOR} ${VARS_FILE}; \
	else \
	  echo "YIKES! No ${VARS_FILE}. Run: make"; \
	fi

SECRETS_FILE = group_vars/all/secret.yml
edit_secrets:
	@if [ -r ${SECRETS_FILE} ]; then \
		trap "ansible-vault encrypt ${SECRETS_FILE}" EXIT; \
		ansible-vault decrypt ${SECRETS_FILE}; \
		${EDITOR} ${SECRETS_FILE}; \
		./bin/redo_passwords; \
	else \
		echo "YIKES! No ${SECRETS_FILE}. Run: make"; \
	fi
