test:
	curl -X POST http://tloring-46978.use1.nitrousbox.com:8080/stations
	@echo
	curl http://tloring-46978.use1.nitrousbox.com:8080 -d orig_name=Claymont -d orig_tminus=20 -d orig_tplus=15 -d dest_name="30th Street Station" -d dest_tminus=15 -d dest_tplus=10

heroku:
	curl -X POST http://r2septa.herokuapp.com/stations
	@echo
	curl http://r2septa.herokuapp.com -d orig_name=Claymont -d orig_tminus=20 -d orig_tplus=15 -d dest_name="30th Street Station" -d dest_tminus=15 -d dest_tplus=10
