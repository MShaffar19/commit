# frozen_string_literal: true

require "commit/event"
require "commit/operation"
require "commit/scope"

RSpec.describe Commit::Operation do
  let(:scope) {
    Commit::Scope.new(path: Dir.pwd)
  }

  let(:event) {
    Commit::Event.global
  }

  describe "::call" do
    before do
      allow(described_class).to receive(:new).with(scope: scope, event: event).and_return(instance)
      allow(instance).to receive(:call)
      allow(instance).to receive(:with_logging).and_yield
    end

    let(:instance) {
      # We have to stub `cleanup` here because rspec instance doubles are dumb.
      #
      instance_double(described_class, cleanup: nil)
    }

    subject {
      described_class.call(scope: scope, event: event)
    }

    it "calls the instance with args and kwargs" do
      described_class.call(:foo, scope: scope, event: event, bar: :baz)

      expect(instance).to have_received(:call).with(:foo, bar: :baz)
    end

    it "returns an instance" do
      expect(subject).to be(instance)
    end
  end

  describe "#scope" do
    subject {
      described_class.new(scope: scope, event: event)
    }

    it "returns the scope" do
      expect(subject.scope).to be(scope)
    end
  end

  describe "#event" do
    subject {
      described_class.new(scope: scope, event: event)
    }

    it "returns the event" do
      expect(subject.event).to be(event)
    end
  end
end
