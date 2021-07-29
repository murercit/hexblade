
cmd_crypt_format() {
  hexblade_crypt_dev="${1?'hexblade_crypt_dev is required'}"
  hexblade_crypt_name="${2:-MAINCRYPTED}"
  if ls "/dev/mapper/$hexblade_crypt_name"; then false; fi
  cryptsetup -v -y --type luks1 --cipher aes-xts-plain64 --hash sha256 luksFormat "$hexblade_crypt_dev"
  cmd_crypt_open "$hexblade_crypt_dev" "$hexblade_crypt_name"
}

cmd_crypt_open() {
  hexblade_crypt_dev="${1?'hexblade_dev_crypt is required'}"
  hexblade_crypt_name="${2:-MAINCRYPTED}"
  if ls "/dev/mapper/$hexblade_crypt_name"; then false; fi
  cryptsetup open "$hexblade_crypt_dev" "$hexblade_crypt_name"
  
  mkdir -p /mnt/hexblade/config/crypt
  echo "$hexblade_crypt_dev" > "/mnt/hexblade/config/crypt/$hexblade_crypt_name.dev"
}

cmd_crypt_tab() {
  hexblade_crypt_dev="$(cat /mnt/hexblade/config/crypt/MAINCRYPTED.dev)"
  [[ "x$hexblade_crypt_dev" != "x" ]]
  hexblade_crypt_id="$(sudo blkid -o value -s UUID "$hexblade_crypt_dev")"
  echo -e "MAINCRYPTED\tUUID=$hexblade_crypt_id\tnone\tluks" | tee /mnt/hexblade/installer/etc/crypttab
  echo 'GRUB_ENABLE_CRYPTODISK=y' | tee /mnt/hexblade/installer/etc/default/grub.d/hexblade-crypt.cfg
  
}

cmd_crypt_format_with_file() {
  [[ -d /mnt/hexblade/secrets ]]
  hexblade_crypt_dev="${1?'hexblade_crypt_dev is required'}"
  hexblade_crypt_name="${2?'hexblade_crypt_name is required'}"
  mkdir -p /mnt/hexblade/secrets/parts
  dd if=/dev/urandom "of=/mnt/hexblade/secrets/parts/$hexblade_crypt_name.key" count=4 bs=512
  if ls "/dev/mapper/$hexblade_crypt_name"; then false; fi
  cryptsetup -v -y --type luks1 --cipher aes-xts-plain64 --hash sha256 luksFormat --key-file "/mnt/hexblade/secrets/parts/$hexblade_crypt_name.key" "$hexblade_crypt_dev"
  cmd_crypt_open_with_file "$hexblade_crypt_dev" "$hexblade_crypt_name"
}

cmd_crypt_open_with_file() {
  hexblade_crypt_dev="${1?'hexblade_crypt_dev is required'}"
  hexblade_crypt_name="${2?'hexblade_crypt_name is required'}"
  if ls "/dev/mapper/$hexblade_crypt_name"; then false; fi
  cryptsetup open --key-file "/mnt/hexblade/secrets/parts/$hexblade_crypt_name.key" "$hexblade_crypt_dev" "$hexblade_crypt_name"
}
