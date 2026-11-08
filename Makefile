.ONESHELL:

.PHONY:
pdf: replication.pdf

replication.pdf: REPLICATION.md
	pandoc $< \
		-o $@ \
		--pdf-engine=xelatex \
		--no-highlight \
		-s
