# mail-server

Ansible Playbooks for setting up a secured ssh mail and web server.

## Quick Start

Prerequisite: Recent version of [Ansible](http://docs.ansible.com) installed
on your control host.

Set up your host's domain name entries as documented here:
https://github.com/hardware/mailserver (you can add the DKIM signature
when the stack is up).

- Create a recent Debian server, using whatever process you choose. I created
  an Debian 9 (Stretch) server in the cloud.

- `make`

- Reboot the installed server.

Once your server is up, from your control host, do `ssh deploy@server.domain`
so you can look at the generated secrets. e.g. to get the DKIM key to add
to your DNS, do:

      cat /mnt/docker/mail/opendkim/{your-domain-name}/mail.txt

On your control host, the first time you run this, it will run `./bin/setup`
and set your `./inventory` files and variable files in `./group_vars/all/`.

Use `make reset` to remove these files and start over.

You can also `make redo` if you make changes to your
base variables and want to push those changes to your server.

If you want to make changes to your secrets (e.g. add/remove users or change
passwords), use `make edit`. This task decrypts and re-encrypts your secrets
using `ansible-vault`.

## User password hashes

Refer to the [Ansible docs regarding user passwords](http://docs.ansible.com/ansible/faq.html#how-do-i-generate-crypted-passwords-for-the-user-module)
to understand how we generate the Linux user password hashes.

To ensure this works, make sure that the `./bin/mkpasswd` script works:

      ./bin/mkpasswd TestTheHash
      $6$JBPVsmzre/hFkiFF$RfmrOFdkXs.QNF515TIGtokseUafj[...]

If you wish to edit your secrets, use the `edit` task, like this:

      $ EDITOR=vi make edit
      Decryption successful

      NOTE: Run "make redo" to push your changes.

      $ make redo

## Saving your settings

After running the process the first time, you can do:

      $ make save

This will create a file `backup-YYYYMMDD-hhmm.tar.gz` which you can stash
and will include your inventory file, variables and vault password.

## References

- [Simple and full-featured mail server using Docker](https://github.com/hardware/mailserver)
- [Securing a Server with Ansible](https://ryaneschinger.com/blog/securing-a-server-with-ansible/)
- [Deploying a mail server with Ansible](https://workaround.org/ispmail/jessie/ansible)
