require 'spec_helper'

describe SlackGamebot::Commands::Decline, vcr: { cassette_name: 'user_info' } do
  let(:user) { Fabricate(:user, user_name: 'username') }
  let(:opponent) { Fabricate(:user) }
  it 'creates a singles challenge' do
    expect do
      expect(message: "gamebot challenge <@#{opponent.user_id}>", user: user.user_id).to respond_with_slack_message(
        "#{user.user_name} challenged #{opponent.user_name} to a match!"
      )
    end.to change(Challenge, :count).by(1)
    challenge = Challenge.last
    expect(challenge.created_by).to eq user
    expect(challenge.challengers).to eq [user]
    expect(challenge.challenged).to eq [opponent]
  end
  it 'requires an opponent' do
    expect do
      expect(message: 'gamebot challenge', user: user.user_id).to respond_with_error(
        'Number of teammates (1) and opponents (0) must match.'
      )
    end.to_not change(Challenge, :count)
  end
  it 'does not butcher names with special characters' do
    expect(message: 'gamebot challenge Jung-hwa', user: user.user_id).to respond_with_error(
      "I don't know who Jung-hwa is! Ask them to _gamebot register_."
    )
  end
end
