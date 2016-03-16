cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o $@.tmp cidata
	mv $@.tmp $@

cidata/meta-data:
	@echo --- | tee $@.tmp
	@echo instance-id: vagrant-$(shell date +%s) | tee -a $@.tmp
	mv $@.tmp $@

.ssh/ssh-vagrant:
	@ssh-keygen -f .ssh/ssh-vagrant -P ''
