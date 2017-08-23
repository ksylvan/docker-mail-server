# Makefile for mail server setup
#
.PHONY: all bootstrap mailserver reset clean \
	edit edit_secrets save help setup rebootstrap do

USER_VAR = deploy_user_name
VAR_FILE = group_vars/all/vars.yml
SECRETS_FILE = group_vars/all/secret.yml
DEPLOY_USER = $(shell grep ${USER_VAR} $(VAR_FILE) 2>/dev/null | \
	awk -F: '{print $$2}')
DOMAIN = $(shell grep domain_name $(VAR_FILE) 2>/dev/null | \
	awk -F: '{print $$2}' | sed 's/^ //')

ifeq "$(DEPLOY_USER)" ""
DEPLOY_USER = deploy
endif

EDITOR ?= vi

all: setup do

do: bootstrap mailserver

setup:
	@./bin/setup

help:
	@echo "all (default) - setup, bootstrap, mailserver."
	@echo "do - Run bootstrap and mailserver tasks (no setup)."
	@echo "bootstrap - run the bootstrap playbook as user root."
	@echo "rebootstrap - run the bootstrap playbook as deploy user."
	@echo "mailserver - deploy mail server stack (as deploy user)."
	@echo "reset - delete inventory and variables for a fresh start."
	@echo "clean - remove any *.retry files."
	@echo "edit - run EDITOR (default vi) on variables file."
	@echo "edit_secrets - decrypt, run EDITOR on secrets file, then encrypt."
	@echo "save - save variables and inventory in backup/domain-YYYYMMDD-hhmm.tgz"
	@echo "help - print this message."

mailserver:
	@echo "Running playbooks using $(DEPLOY_USER) user"
	ansible-playbook -u $(DEPLOY_USER) mailserver.yml

# bootstrap sets up a secure debian server
bootstrap:
	@if [ -r .bootstrap_done ]; then \
	  ansible-playbook -u $(DEPLOY_USER) bootstrap.yml; \
	else \
	  ansible-playbook -u root -k bootstrap.yml; \
	fi

# bootstrap explicitly as deploy user
rebootstrap:
	ansible-playbook -u $(DEPLOY_USER) bootstrap.yml

# GENERATED FILES
GEN = inventory group_vars .vault_pass.txt .bootstrap_done

# clean up and start over
reset:
	rm -rf $(GEN)
	touch .vault_pass.txt; chmod 600 .vault_pass.txt

# save the current set of variables and vault password
save:
	name=backup/$(DOMAIN)-`date +'%Y%m%d-%H%M'`.tar.gz; \
	tar cvzf $$name $(GEN)

# simple cleanup of ansible cruft
clean:
	rm -rf *.retry

edit:
	@if [ -r $(VAR_FILE) ]; then \
		$(EDITOR) $(VAR_FILE); \
	else \
	  echo "YIKES! No $(VAR_FILE). Run: make"; \
	fi

edit_secrets:
	@if [ -r $(SECRETS_FILE) ]; then \
		trap "ansible-vault encrypt $(SECRETS_FILE)" EXIT; \
		ansible-vault decrypt $(SECRETS_FILE); \
		$(EDITOR) $(SECRETS_FILE); \
		./bin/redo_passwords; \
	else \
		echo "YIKES! No $(SECRETS_FILE). Run: make"; \
	fi
