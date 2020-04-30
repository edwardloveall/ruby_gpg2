shared_examples(
    "a command with global config"
) do |command_name, arguments = [], options = {}|
  let(:arguments_string) do
    arguments.empty? ? "" : " #{arguments.join(" ")}"
  end

  let(:command_string) { "#{command_name}#{arguments_string}" }
  let(:binary) { "path/to/binary" }

  it 'does not set a home directory by default' do
    command = subject.class.new

    expect(Open4).to(
        receive(:spawn)
            .with(
                /^#{binary} ((?!--homedir).)*#{command_string}$/,
                any_args))

    command.execute(options)
  end

  it 'includes the provided home directory' do
    home_directory = './gpg'

    command = subject.class.new

    expect(Open4).to(
        receive(:spawn)
            .with(
                /^#{binary}.* --homedir="#{home_directory}" .*#{command_string}$/,
                any_args))

    command.execute(
        options.merge(home_directory: home_directory))
  end
end
