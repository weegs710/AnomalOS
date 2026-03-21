use crate::{
    common::{AlbumInfo, ArtistInfo, SongInfo},
    config::APPLICATION_USER_AGENT,
    utils::meta_provider_settings,
};

use gio::prelude::SettingsExt;
use reqwest::{blocking::Client, header::USER_AGENT};

use super::{
    super::{models, MetadataProvider},
    models::DeezerSearchResponse,
    PROVIDER_KEY,
};

pub const API_ROOT: &str = "https://api.deezer.com/";

pub struct DeezerWrapper {
    client: Client,
}

impl MetadataProvider for DeezerWrapper {
    fn new() -> Self {
        Self {
            client: Client::new(),
        }
    }

    fn get_album_meta(
        &self,
        _key: &mut AlbumInfo,
        existing: Option<models::AlbumMeta>,
    ) -> Option<models::AlbumMeta> {
        existing
    }

    fn get_artist_meta(
        &self,
        key: &mut ArtistInfo,
        existing: Option<models::ArtistMeta>,
    ) -> Option<models::ArtistMeta> {
        if !meta_provider_settings(PROVIDER_KEY).boolean("enabled") {
            return existing;
        }
        if !meta_provider_settings(PROVIDER_KEY).boolean("download-artist-avatar") {
            return existing;
        }
        // Skip if an upstream provider already found an image
        if existing.as_ref().map_or(false, |m| !m.image.is_empty()) {
            return existing;
        }

        let resp = self
            .client
            .get(format!("{API_ROOT}search/artist"))
            .query(&[("q", key.name.as_str()), ("limit", "1")])
            .header(USER_AGENT, APPLICATION_USER_AGENT)
            .send();

        match resp {
            Ok(r) => match r.text() {
                Ok(text) => match serde_json::from_str::<DeezerSearchResponse>(&text) {
                    Ok(parsed) => {
                        if let Some(artist) = parsed.data.into_iter().next() {
                            // Deezer's placeholder URL for unmatched artists contains a double
                            // slash, e.g. "https://e-cdns-images.dzcdn.net/images/artist//250x250-..."
                            if artist.picture_xl.contains("/images/artist//") {
                                return existing;
                            }
                            let mut meta =
                                existing.unwrap_or_else(|| models::ArtistMeta::from_key(key));
                            meta.image.push(models::ImageMeta {
                                size: models::ImageSize::Mega,
                                url: artist.picture_xl,
                            });
                            Some(meta)
                        } else {
                            existing
                        }
                    }
                    Err(_) => existing,
                },
                Err(_) => existing,
            },
            Err(_) => existing,
        }
    }

    fn get_lyrics(&self, _key: &SongInfo) -> Option<models::Lyrics> {
        None
    }
}
