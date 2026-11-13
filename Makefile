.ONESHELL:

.PHONY:
build: replication.pdf

replication.pdf: REPLICATION.md
	pandoc $< \
		-o $@ \
		--pdf-engine=xelatex \
		--no-highlight \
		-s

clean:
	rm -f replication.pdf

.PHONY:
deploy:
	@if [ -z "$$TARGET" ] ;then \
  		echo "ERROR: TARGET must be defined" ;\
  		exit 1 ; \
  	fi
  	# sync everything but binaries
	rsync -aiv \
		--exclude='demo' \
		--exclude='low_level_interface' \
		--exclude='reset_gpio' \
		--exclude='check_*' \
		pendulum_pi \
		$$TARGET:
