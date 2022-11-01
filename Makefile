.PHONY:all
all: gs98.mod as09.mod
# filename %.zams, %.mod are set in inlist_$*_pms, inlist_$*_zams
%.zams:
	mkdir -p LOGS_$*_pms photos_$*_pms
	ln -s inlist_$*_pms inlist_project
	ln -s LOGS_$*_pms LOGS
	ln -s photos_$*_pms photos
	./rn
	rm LOGS photos inlist_project
%.mod: %.zams
	mkdir -p LOGS_$*_zams photos_$*_zams
	ln -s inlist_$*_zams inlist_project
	ln -s LOGS_$*_zams LOGS
	ln -s photos_$*_zams photos
	./rn
	rm LOGS photos inlist_project

.SECONDARY:
