namespace :rswag do
  namespace :ui do

    desc 'TODO'
    task :copy_assets, [ :dest ] do |t, args|
      dest = args[:dest]
      FileUtils.rm_r(dest, force: true)
      FileUtils.mkdir_p(dest)
      FileUtils.cp_r(Dir.glob("#{Rswag::Ui.config.assets_root}/{*.js,*.png,*.css}"), dest)
    end
  end
end
