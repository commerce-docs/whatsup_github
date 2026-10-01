# frozen_string_literal: true

# Stubs ~/.netrc presence and permissions, shared by Client and EnterpriseClient specs.
module NetrcHelper
  def stub_netrc(exists:)
    path = File.expand_path('~/.netrc')
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(path).and_return(exists)
  end

  def stub_netrc_permissions(mode)
    stub_netrc(exists: true)
    allow(File).to receive(:stat).and_call_original
    allow(File).to receive(:stat).with(File.expand_path('~/.netrc')).and_return(double(mode: mode))
  end
end
