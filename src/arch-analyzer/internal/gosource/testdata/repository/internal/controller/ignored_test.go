package controller

func ignored(router interface{ GET(string, ...any) }) {
	router.GET("/test-only")
}
