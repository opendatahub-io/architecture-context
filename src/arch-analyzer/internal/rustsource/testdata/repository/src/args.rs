pub struct Args {
    #[clap(default_value = "8033", long, env)]
    pub http_port: u16,
    #[clap(
        default_value = "8034",
        long,
        env
    )]
    pub health_http_port: u16,
    #[clap(long, env)]
    pub tls_cert_path: Option<String>,
    #[clap(long, env)]
    pub tls_key_path: Option<String>,
    #[clap(long, env)]
    pub tls_client_ca_cert_path: Option<String>,
}
