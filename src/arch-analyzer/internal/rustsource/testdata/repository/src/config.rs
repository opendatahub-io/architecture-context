pub struct ServiceConfig {
    pub api_token: Option<String>,
}

pub struct TlsConfig {
    pub cert_path: String,
    pub key_path: String,
}
