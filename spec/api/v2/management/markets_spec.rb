# encoding: UTF-8
# frozen_string_literal: true

describe API::V2::Management::Markets, type: :request do
  before do
    defaults_for_management_api_v1_security_configuration!
    management_api_v1_security_configuration.merge! \
      scopes: {
        write_markets: { permitted_signers: %i[alex jeff], mandatory_signers: %i[alex] },
        read_markets: { permitted_signers: %i[alex jeff], mandatory_signers: %i[alex] },
      }
  end

  describe 'update market' do
    def request
      put_json '/api/v2/management/markets/update', multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    let(:data) { {} }
    let(:signers) { %i[alex jeff] }
    let(:market) { Market.find_spot_by_symbol(:btcusd) }
    let!(:engine) { create(:engine) }

    it 'should validate min_price param' do
      data.merge!(id: market.symbol, min_price: -10.0)
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/min_price does not have a valid value/i)
    end

    it 'should validate min_amount param' do
      data.merge!(id: market.symbol, min_amount: -123.0)
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/min_amount does not have a valid value/i)
    end

    it 'should validate amount_precision param' do
      data.merge!(id: market.symbol, amount_precision: -100.0)
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/amount_precision does not have a valid value/i)
    end

    it 'should validate price_precision param' do
      data.merge!(id: market.symbol, price_precision: -100.0)
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/price_precision does not have a valid value/i)
    end

    it 'should validate max_price param' do
      data.merge!(id: market.symbol, max_price: -1)
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/max_price does not have a valid value/i)
    end

    it 'should validate position param' do
      data.merge!(id: market.symbol, position: -100.0)
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/position does not have a valid value/i)
    end

    it 'should validate state param' do
      data.merge!(id: market.symbol, state: 'blah-blah')
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/state does not have a valid value/i)
    end

    it 'should check required params' do
      request

      expect(response).to have_http_status 422
      expect(response.body).to match(/id is missing/i)
    end

    it 'should update market' do
      data.merge!(id: market.symbol, state: 'disabled', min_amount: '0.1')
      request

      expect(response).to have_http_status 200

      result = JSON.parse(response.body)
      expect(result.fetch('id')).to eq market.symbol
      expect(result.fetch('state')).to eq 'disabled'
      expect(result.fetch('min_amount')).to eq '0.1'
    end

    it 'should update engine_id of spot' do
      prev_engine_id = market.engine_id
      data.merge!(id: market.symbol, engine_id: engine.id)
      request

      expect(response).to have_http_status 200

      result = JSON.parse(response.body)
      expect(result.fetch('id')).to eq market.symbol
      expect(result.fetch('engine_id')).not_to eq prev_engine_id
      expect(result.fetch('engine_id')).to eq engine.id
    end

    it 'should update engine_id' do
      market = Market.find_qe_by_symbol('btceth')
      prev_engine_id = market.engine_id
      data.merge!(id: market.symbol, type: 'qe', engine_id: engine.id)
      request

      expect(response).to have_http_status 200

      result = JSON.parse(response.body)
      expect(result.fetch('id')).to eq market.symbol
      expect(result.fetch('engine_id')).not_to eq prev_engine_id
      expect(result.fetch('engine_id')).to eq engine.id
    end
  end

  describe 'fetch markets list' do
    def request
      post_json '/api/v2/management/markets/list', multisig_jwt_management_api_v1({ data: data }, *signers)
    end


    let(:data) { {} }
    let(:signers) { %i[alex jeff] }

    let(:expected_keys) do
      %w[id symbol name type base_unit quote_unit min_price max_price
         min_amount amount_precision price_precision state position engine_id created_at updated_at]
    end

    it 'lists enabled spot markets' do
      request
      expect(response).to have_http_status 200
      result = JSON.parse(response.body)

      expect(result.size).to eq Market.spot.count
      result.each do |market|
        expect(market.keys).to eq expected_keys
      end
    end

    it 'lists enabled qe markets' do
      data[:type] = 'qe'
      request
      expect(response).to have_http_status 200
      result = JSON.parse(response.body)

      expect(result.size).to eq Market.qe.count
      result.each do |market|
        expect(market.keys).to eq expected_keys
      end
    end
  end
end
