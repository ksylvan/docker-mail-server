# Makefile for mail server setup
#
.PHONY: all bootstrap mailserver rebootstrap reset clean edit redo save

USER_VAR=server_deploy_user_name
VAR_FILE=group_vars/all/vars.yml
DEPLOY_USER=$(shell grep ${USER_VAR} ${VAR_FILE} >/dev/null 2>&1 | \
	awk -F: '{print $$2}')

ifeq "${DEPLOY_USER}" ""
DEPLOY_USER=deploy
endif

all: ${ROLES}
	@if [ ! -r ${VAR_FILE} ]; then \
		./bin/setup; \
		if [ $$? -ne 0 ]; then exit $$?; fi; \
		make bootstrap; \
	fi; \
	make mailserver

mailserver:
	echo "Running playbook using ${DEPLOY_USER} user"; \
	ansible-playbook -u ${DEPLOY_USER} mailserver.yml

# bootstrap sets up a secure ubuntu server (the first time)
bootstrap:
	ansible-playbook -u root -k bootstrap.yml

# since root ssh logins are disabled, need to run this when boostrapping again
rebootstrap:
	ansible-playbook -u ${DEPLOY_USER} bootstrap.yml

redo: rebootstrap all

# GENERATED FILES
GEN=inventory group_vars .vault_pass.txt

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

SECRETS_FILE=group_vars/all/secret.yml
edit:
	@if [ -z "$$EDITOR" ]; then \
		echo "EDITOR environment variable must be set."; exit 1; \
	fi
	@if [ -r ${SECRETS_FILE} ]; then \
		trap "ansible-vault encrypt ${SECRETS_FILE}" EXIT; \
		ansible-vault decrypt ${SECRETS_FILE}; \
		$$EDITOR ${SECRETS_FILE}; \
		./bin/redo_passwords; \
	fi
