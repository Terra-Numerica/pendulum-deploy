.ONESHELL:

.PHONY:
pdf: replication.pdf

replication.pdf: REPLICATION.md
	pandoc $< \
		-o $@ \
		--pdf-engine=xelatex \
		--no-highlight \
		-s

.PHONY:
deploy:
	@if [ -z "$$TARGET" ] ;then \
  		echo "ERROR: TARGET must be defined" ;\
  		exit 1 ; \
  	fi
	rsync -aiv pendulum_pi $$TARGET:
