package main

import "github.com/julienschmidt/httprouter"

func routes(router *httprouter.Router) {
	router.GET("/nested", nil)
}
