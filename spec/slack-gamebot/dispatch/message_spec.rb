require 'spec_helper'

describe SlackGamebot::Dispatch::Message do
  let(:app) { SlackGamebot::App.new }
  before do
    SlackGamebot.config.user = 'gamebot'
  end
  it 'gamebot' do
    expect(subject).to receive(:message).with('channel', SlackGamebot::ASCII)
    app.send(:message, text: 'gamebot', channel: 'channel', user: 'user')
  end
  it 'hi' do
    expect(subject).to receive(:message).with('channel', 'Hi <@user>!')
    app.send(:message, text: 'gamebot hi', channel: 'channel', user: 'user')
  end
  it 'invalid command' do
    expect(subject).to receive(:message).with('channel', "Sorry <@user>, I don't understand that command!")
    app.send(:message, text: 'gamebot foobar', channel: 'channel', user: 'user')
  end
  context 'as a user', vcr: { cassette_name: 'user_info' } do
    context 'register' do
      it 'registers a new user' do
        expect(subject).to receive(:message).with('channel', "Welcome <@user>! You're ready to play.")
        app.send(:message, text: 'gamebot register', channel: 'channel', user: 'user')
      end
      it 'renames an existing user' do
        Fabricate(:user, user_id: 'user')
        expect(subject).to receive(:message).with('channel', "Welcome back <@user>, I've updated your registration.")
        app.send(:message, text: 'gamebot register', channel: 'channel', user: 'user')
      end
      it 'already registered' do
        Fabricate(:user, user_id: 'user', user_name: 'username')
        expect(subject).to receive(:message).with('channel', "Welcome back <@user>, you're already registered.")
        app.send(:message, text: 'gamebot register', channel: 'channel', user: 'user')
      end
    end
    context 'with a user record' do
      context 'challenge' do
        it 'creates a singles challenge' do
          user = Fabricate(:user, user_name: 'username')
          opponent = Fabricate(:user)
          expect do
            expect(subject).to receive(:message).with('channel', "#{user.user_name} challenged #{opponent.user_name} to a match!")
            app.send(:message, text: "gamebot challenge <@#{opponent.user_id}>", channel: 'channel', user: user.user_id)
          end.to change(Challenge, :count).by(1)
          challenge = Challenge.last
          expect(challenge.created_by).to eq user
          expect(challenge.challengers).to eq [user]
          expect(challenge.challenged).to eq [opponent]
        end
        it 'requires an opponent' do
          expect do
            expect do
              app.send(:message, text: 'gamebot challenge', channel: 'channel', user: 'user')
            end.to raise_error(ArgumentError, 'Number of teammates (1) and opponents (0) must match.')
          end.to_not change(Challenge, :count)
        end
      end
    end
    context 'with a challenge' do
      before do
        @challenged = Fabricate(:user, user_name: 'username')
        @challenge = Fabricate(:challenge, challenged: [@challenged])
      end
      it 'accept' do
        expect(subject).to receive(:message).with('channel', "#{@challenged.user_name} accepted #{@challenge}.")
        app.send(:message, text: 'gamebot accept', channel: 'channel', user: @challenged.user_id)
        expect(@challenge.reload.state).to eq ChallengeState::ACCEPTED
      end
      it 'decline' do
        expect(subject).to receive(:message).with('channel', "#{@challenged.user_name} declined #{@challenge}.")
        app.send(:message, text: 'gamebot decline', channel: 'channel', user: @challenged.user_id)
        expect(@challenge.reload.state).to eq ChallengeState::DECLINED
      end
    end
  end
end