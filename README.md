# mail-server

Ansible Playbooks for setting up a secured ssh, mail, and web server.

## Quick Start

Prerequisite: Recent version of [Ansible](http://docs.ansible.com) installed
on your control host.

Set up your host's domain name entries as documented here:
https://github.com/ksylvan/mailserver (you can add the DKIM signature
when the stack is up).

To start, you'll need to have the following set up in your DNS (`A.B.C.D`
represents your IP address):

| HOSTNAME | CLASS | TYPE | PRIORITY | VALUE |
| -------- | ----- | ---- | -------- | ----- |
| @ | IN | A/AAAA | any | A.B.C.D |
| mail | IN | A/AAAA | any | A.B.C.D |
| @ | IN | MX | 10 | mail.domain.tld. |
| www | IN | CNAME | any | mail.domain.tld. |
| postfixadmin | IN | CNAME | any | mail.domain.tld. |
| webmail | IN | CNAME | any | mail.domain.tld. |

- Create a recent Debian or Fedora server, using whatever process you choose.
  I created a Debian 9 (Stretch) server in the cloud. Also tested with
  a Fedora 26 Server instance.

- `make`

- Reboot the installed server.

- Add additional DNS records (for `SPF`, `DKIM`, and `DMARC`) as
  documented [here](https://github.com/ksylvan/mailserver) to increase
  your reputation score.

Once your server is up, from your control host, do `ssh deploy@server.domain`
so you can look at the generated secrets. e.g. to get the DKIM key to add
to your DNS, do:

      ssh deploy@server.domain
      cat /mnt/docker/mail/opendkim/{your-domain-name}/mail.txt

- At this point, visit your `postfixadmin` setup script and follow the
  instructions here: https://github.com/hardware/mailserver/wiki/Postfixadmin-initial-configuration

- Using `postfixadmin`, set up your super-administrator account, then set up your domain,
  and proceed to set up mailboxes for `admin` and `contact`. Now set up aliases for
  the following:

| ALIAS | MAILBOX |
| -------- | ----- |
| abuse | admin@yourdomain.tld |
| hostmaster | admin@yourdomain.tld |
| noc | admin@yourdomain.tld |
| postmaster | admin@yourdomain.tld |
| spam | admin@yourdomain.tld |
| sales | contact@yourdomain.tld |
| webform | contact@yourdomain.tld |

- Set up your Rainloop (webmail) configuration. Follow the instructions
  here: https://github.com/hardware/mailserver/wiki/Rainloop-initial-configuration

- Using the RainLoop admin panel, make sure to set up your `ManageSieve` and
  white-lists for users you allow to login to your domain.

- In the RainLoop admin, go to the `Plugins` and enable
  the `postfixadmin-change-password` plugin. You will have to ensure that
  the plugin settings are set like this:

| PLUGIN SETTING | VALUE |
| -------- | ----- |
| MySQL Host | mariadb |
| MySQL Port | 3306 |
| MySQL Database | postfix |
| MySQL table | mailbox |
| MySQL username column | username |
| MySQL password column | password |
| MySQL User | postfix |
| MySQL Password | {MYSQL postfix user password} |
| Encrypt | md5encrypt |
| Allowed Emails | * |

The password to use in the change password settings is the `postfix` database
user password. You can get it by `ssh` into your host and examining the
`docker-compose.yml` file:

    $ ssh deploy@yourdomain.tld
    $ grep MYSQL_PASSWORD docker-compose.yml
      - MYSQL_PASSWORD=XXXXXXXXX

Setting up the `postfixadmin-change-password` plugin will allow users
to change their mailbox passwords.

## Postfix Config customization

You can add postfix customizations to `/mnt/docker/mail/postfix/custom.conf` on your mailserver
machine and restart the stack.

More info about postfix overrides here: https://github.com/ksylvan/mailserver#override-postfix-configuration

## Web Site files

The site at `www.yourdomain.tld` simply directs to the `contact` app
which renders a simple Contact Form as the front page of your your domain.

If you place files in `www/yourdomain.tld/`, the Ansible playbook will
create an alterate setup:

* /contact will refer to the Contact form served by the PHP container.
* / will refer to what you place in `www/yourdomain.tld/files/`
* /~user will refer to what you place in `www/yourdomain.tld/people/user/`

Note that files placed in `www/` are ignored by git and will have
to be backed up.

## Redeploying, starting over.

On your control host, the first time you run this, it will run `./bin/setup`
and set your `./inventory` files and variable files in `./group_vars/all/`.

Subsequent runs of `./bin/setup` will read the stored values and present
them as defaults.

Use `make reset` to remove these files and start over.

You can also `make redo` if you make changes to your
base variables and want to push those changes to your server.

If you want to make changes to your secrets (e.g. change passwords),
use `make edit_secrets`. This task decrypts and re-encrypts your secrets
using `ansible-vault`.

Run `make help` for a quick explanation of all `Makefile` tasks.

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

This will create a file `backup/{domain}-YYYYMMDD-hhmm.tar.gz` which you can stash
and will include your inventory file, variables and vault password.

## References

- [Simple and full-featured mail server using Docker](https://github.com/hardware/mailserver)
- [Securing a Server with Ansible](https://ryaneschinger.com/blog/securing-a-server-with-ansible/)
- [Deploying a mail server with Ansible](https://workaround.org/ispmail/jessie/ansible)
