# frozen_string_literal: true

require 'spec_helper'

shared_examples(
  'a command with batch config'
) do |command_name, arguments = [], options = {}|
  let(:arguments_string) do
    arguments.empty? ? '' : " #{arguments.join(' ')}"
  end

  let(:command_string) { "#{command_name}#{arguments_string}" }
  let(:binary) { 'path/to/binary' }
  let(:executor) { Lino::Executors::Mock.new }

  before do
    Lino.configure do |config|
      config.executor = executor
    end
  end

  after do
    Lino.reset!
  end

  it 'includes the batch flag by default' do
    command = described_class.new

    command.execute(options)

    expect(executor.executions.first.command_line.string)
      .to(match(/^#{binary}.* --batch .*#{command_string}$/))
  end

  it 'does not include the batch flag when batch is false' do
    command = described_class.new

    command.execute(
      options.merge(batch: false)
    )

    expect(executor.executions.first.command_line.string)
      .to(match(/^#{binary} ((?!--batch).)*#{command_string}$/))
  end

  it 'includes the batch flag when batch is true' do
    command = described_class.new

    command.execute(
      options.merge(batch: true)
    )

    expect(executor.executions.first.command_line.string)
      .to(match(/^#{binary}.* --batch .*#{command_string}$/))
  end
end
