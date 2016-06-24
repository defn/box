cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o $@.tmp cidata
	mv $@.tmp $@

cidata/meta-data: $(CACHE_DIR)/.ssh/ssh-vagrant
	@echo --- | tee $@.tmp
	@echo instance-id: vagrant-$(shell date +%s) | tee -a $@.tmp
	mv $@.tmp $@

cidata/user-data: $(CACHE_DIR)/.ssh/ssh-vagrant
	libexec/gen-user-data > cidata/user-data.tmp
	mv cidata/user-data.tmp cidata/user-data

$(CACHE_DIR)/.ssh/ssh-vagrant:
	@mkdir -p $(shell dirname $@)
	@ssh-keygen -f $@ -P ''

key:
	@aws ec2 import-key-pair --key-name vagrant-$(shell md5 -q /vagrant/.ssh/ssh-vagrant.pub) --public-key-material "$(shell cat /vagrant/.ssh/ssh-vagrant.pub)"
