module Surely
  class Daemon
    def initialize(env)
      @env = env
      settings_file = File.join(@env['HOME'], '.surely.yml')
      @settings = File.exists?(settings_file) ? YAML.load_file(settings_file) : {}
    end

    def start
      directory = @settings['directory']
      directory ||= `defaults read com.apple.screencapture location 2> /dev/null`.chomp
      directory = "#{@env['HOME']}/Desktop" if directory.empty?

      @uploader = Uploader.new(@env, @settings, directory)
      @uploader.add_client!
      @uploader.authorize!

      Raad::Logger.info "Listening to changes on #{directory}..."

      listener = Listen.to(directory)
      listener.filter(/\.(png|jpg|jpeg|gif)$/i)
      listener.change(&@uploader.callback)
      listener.start

      sleep(1) while !Raad.stopped?
    end
  end
end
