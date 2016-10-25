#frozen-string-literal: true
require 'json'
require File.expand_path '../../schemas/charge_schema', __FILE__

RSpec.describe '[POST] /charge' do
  include Rack::Test::Methods

  let(:app) { App.app }

  let(:default_params) do
    {
      amount: 10,
      card: {
        holder: 'KiiK Company',
        number: '4200000000000000',
        expiration_month: 12,
        expiration_year: 2017,
        cvv: "096"
      },
      intermediaries: intermediaries
    }
  end

  let(:intermediaries) { [{ "fee": 0, "flat": 5, "description": "Tax of KiiK" }] }
  let(:parsed_body) { JSON.parse last_response.body }

  context 'with valid json schema' do
    before { post_json default_params }

    it 'responds with success' do
      expect(last_response).to be_ok
    end

    it 'renders json' do
      expect(last_response.content_type).to eq 'application/json'
    end

    context 'parsing response' do
      it 'is validated with ChargeSchema::RESPONSE' do
        expect(JSON::Validator.validate(ChargeSchema::RESPONSE, parsed_body)).to eq true
      end

      it 'keeps `amount` value from request' do
        amount = default_params[:amount]
        expect(parsed_body["amount"]).to eq amount
      end

      it 'keeps `fee`, `flat` and `description` values from request' do
        request_intermediary = default_params[:intermediaries][0]
        response_intermediary = parsed_body["intermediaries"][0]

        expect(response_intermediary["fee"]).to eq request_intermediary[:fee]
        expect(response_intermediary["flat"]).to eq request_intermediary[:flat]
        expect(response_intermediary["description"]).to eq request_intermediary[:description]
      end
    end

    context 'calculating intermediaries\' amount' do
      context 'given one intermediary' do
        subject { parsed_body["intermediaries"][0]['amount'] }

        it { is_expected.to eq 5 }

        context 'without fee attribute' do
          let(:intermediaries) { [{ flat: 1 }] }

          it { is_expected.to eq 1 }
        end

        context 'without flat attribute' do
          let(:intermediaries) { [{ fee: 0.2 }] }

          it { is_expected.to eq 2 }
        end

        context 'with only description attribute' do
          let(:intermediaries) { [{ description: 'Custom Tax' }] }

          it { is_expected.to eq 0 }
        end
      end

      context 'with more than one intermediary' do
        let(:intermediaries) do
          [
            { fee: 0.1, flat: 0.4, description: "Tax Random1" },
            { fee: 0.3, flat: 1, description: "Tax Random2" }
          ]
        end

        subject(:response_intermediaries) { parsed_body["intermediaries"] }

        it 'calculates intermediaries\' amount' do
          amounts = response_intermediaries.map { |h| h["amount"] }

          expect(amounts.count ).to eq 2
          expect(amounts).to match_array [1.4, 4]
        end
      end

      context 'with no intermediaries' do
        before do
          default_params.delete(:intermediaries)
          post_json default_params
        end

        subject { parsed_body["intermediaries"] }

        it { is_expected.to match_array [] }
      end

      context 'when intermediaries amount is greater than charge amount' do
        let(:intermediaries) do
          [
            { fee: 0.6, flat: 1 },
            { fee: 0.3, flat: 3 }
          ]
        end

        let(:bad_request_message) do
          "The sum of the intermediaries amounts is greater than the amount of the transaction."
        end

        it 'responds with bad request' do
          expect(last_response.status).to eq 400
        end

        it 'responds with error message' do
          expect(last_response.body).to eq bad_request_message
        end
      end
    end
  end

  context 'with invalid json schema' do
    before do
      default_params.delete(:amount)
      post_json default_params
    end

    it 'responds with bad request' do
      expect(last_response.status).to eq 400
    end
  end

  def post_json(params)
    post '/charge', params.to_json, { "CONTENT_TYPE" => "application/json" }
  end
end
