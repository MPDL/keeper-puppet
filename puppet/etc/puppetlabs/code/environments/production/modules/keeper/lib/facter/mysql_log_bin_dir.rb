Facter.add(:mysql_log_bin_dir) do
  setcode do
    Facter::Util::Resolution.exec('cat /etc/puppetlabs/code/environments/production/modules/keeper/files/keeper.ini 2>&1 | grep __LOG_BIN_DIR__ | cut -d "=" -f2 | xargs dirname' )
  end
end

