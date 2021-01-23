# Be sure to restart your server when you modify this file.

if Rails.version.first.to_i < 5
  # Your secret key for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  TestApp::Application.config.secret_token = '60f36cd33756d73f362053f1d45256ae50d75440b634ae73b070a6e35a2df38692f59e28e5ecbd1f9f2e850255f6d29a468bc59ac4484c2b7f0548ddbfc1b870'
else
  # See http://guides.rubyonrails.org/upgrading_ruby_on_rails.html#config-secrets-yml
  TestApp::Application.config.secret_key_base = 'f6a820cc8aa76094583cd68ef46a735e25e3278648086355f8bd24721f036959c728c06a28dcecfe695f17ae2db44dfa1424f22b81377f2a1496d4e19f6f7faa'
end
