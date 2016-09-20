cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o $@.tmp cidata
	mv $@.tmp $@

cidata/meta-data: cidata/user-data Makefile
	@mkdir -p cidata
	@echo --- | tee $@.tmp
	@echo instance-id: $(shell basename $(shell pwd)) | tee -a $@.tmp
	mv $@.tmp $@

cidata/user-data: cidata/user-data.template .ssh/ssh-vagrant Makefile
	@cat "$<" | env CONTAINER_SSH_KEY="$(shell cat .ssh/ssh-vagrant.pub)" envsubst '$$USER $$CONTAINER_SSH_KEY $$CACHE_VIP' | tee "$@.tmp"
	mv "$@.tmp" "$@"

.ssh/ssh-vagrant:
	@mkdir -p $(shell dirname $@)
	@ssh-keygen -f $@ -P '' -C "vagrant@$(shell uname -n)"

key: .ssh/ssh-vagrant
	@aws ec2 import-key-pair --key-name vagrant-$(shell md5 -q .ssh/ssh-vagrant.pub) --public-key-material "$(shell cat .ssh/ssh-vagrant.pub)"
