cidata.iso: cidata/user-data cidata/meta-data
	mkisofs -R -V cidata -o cidata.iso.tmp cidata
	mv cidata.iso.tmp cidata.iso
