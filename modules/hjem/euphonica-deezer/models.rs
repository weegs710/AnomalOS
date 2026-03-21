use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct DeezerArtist {
    pub picture_xl: String,
}

#[derive(Deserialize, Debug)]
pub struct DeezerSearchResponse {
    pub data: Vec<DeezerArtist>,
}
