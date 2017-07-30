# mail-server

Ansible Playbooks for setting up a secured ssh mail and web server.

## Quick Start

Prerequisite: Recent version of [Ansible](http://docs.ansible.com) installed
on your control host.

- Create a recent Debian server, using whatever process you choose. I created
  an Debian 9 (Stretch) server in the cloud.

- `make`

- Reboot the installed server.

The first time you run this, it will run `./bin/setup` and set your
`./inventory` files and variable files in `./group_vars/all/`.

Use `make reset` to remove these files and start over.

You can also `make redo` if you make changes to your
base variables and want to push those changes to your server.

If you want to make changes to your secrets (e.g. add/remove users or change
passwords), use `make edit`. This task decrypts and re-encrypts your secrets
using `ansible-vault`.

## User password hashes

Refer to the [Ansible docs regarding user passwords](http://docs.ansible.com/ansible/faq.html#how-do-i-generate-crypted-passwords-for-the-user-module)
to understand how we generate the Linux user password hashes to make or
modify user accounts on the VPN server.

To ensure this works, make sure that the `./bin/mkpasswd` script works:

      ./bin/mkpasswd TestTheHash
      $6$JBPVsmzre/hFkiFF$RfmrOFdkXs.QNF515TIGtokseUafj[...]

If you wish to edit your secrets, use the `edit` task, like this:

      $ EDITOR=vi make edit
      Decryption successful

      NOTE: Run "make redo" to push your changes.

      $ make redo

## References

- [Securing a Server with Ansible](https://ryaneschinger.com/blog/securing-a-server-with-ansible/)
- [Deploying a mail server with Ansible](https://workaround.org/ispmail/jessie/ansible)
