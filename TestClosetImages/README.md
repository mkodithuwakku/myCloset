# Local test closet images

Place local garment test images in this directory. Image files are ignored by Git so personal or third-party test photos are not published accidentally.

With an iPhone Simulator booted, load every supported image into Simulator Photos from the repository root:

```sh
./scripts/load_test_closet_images.sh
```

Then open **Closet → Import** in myCloset and select the images as one batch. The app performs clothing-type and color suggestions locally.

Supported development formats are JPEG, PNG, HEIC, HEIF, and WebP. Because Simulator Photos does not accept WebP directly, the loader creates temporary JPEG copies for import and leaves the originals unchanged. Repeated loader runs skip content already added to that Simulator, including duplicate source files with different names. Keep only test images you have permission to use.
