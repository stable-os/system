# system

System respository

## Editions

- postflash
  - Gets installed using the install iso and downloads the actual image
  - This step exists to handle devices with too little memory to download the image in one go
  - Tiny (goal is <1GB)
    - Might have to get a different kernel config that doesn't include display, mouse, touchpad, etc drivers
