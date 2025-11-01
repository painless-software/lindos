use std::env;
use std::fs;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-changed=src/lib.rs");
    println!("cargo:rerun-if-changed=cbindgen.toml");

    let crate_dir = env::var("CARGO_MANIFEST_DIR").expect("Missing manifest dir");
    let out_dir = PathBuf::from(&crate_dir).join("include");
    fs::create_dir_all(&out_dir).expect("Unable to create include directory");

    let header_path = out_dir.join("lindos.h");
    let config = cbindgen::Config::from_file(PathBuf::from(&crate_dir).join("cbindgen.toml")).ok();

    let mut builder = cbindgen::Builder::new();
    builder = builder
        .with_crate(&crate_dir)
        .with_language(cbindgen::Language::C);

    if let Some(cfg) = config {
        builder = builder.with_config(cfg);
    }

    builder
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file(&header_path);
}
