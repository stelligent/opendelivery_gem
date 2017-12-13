require File.expand_path('../../spec_helper', __FILE__)

describe OpenDelivery::Domain do
  let(:domain_name) { 'test-domain' }
  let(:encrypted_hash) { "A3a2fG3S7AAe4n1uRtFGWi9cKsGuWRwjdmNz1z05nN7vpA6kSVfK0QzpT68b\ngv1pu7PczaNqLimhB3ZE3Qj/A4Bzka13ZFBawhhY+oXcWBc0RmeWgOaYJf0i\n7Y4MnieKYJ8xsy87YD9n0bWBPDcAPkUWT282VTlTEcz1u1TbIJzTJOsiTj6c\nYgxUY7lS9A9ZrIqrMMtTodq/A+zm1GYifJn1kTn2oOmj/NkwR0P6Sgj14Djg\nOH/TfktTDppNH3/RKQjJVSS6JTpW1RhCek9nHKiI3lUrqhyUV1MZ66Pzz0w7\n/lo/ETK9koBHtfqZBOHREGO3iD7iD1NcqYNIIz7ZyQ==\n|cG6CmVscfexgkBs54jYtrQ==\n" }
  let(:simpledb) do
    Aws::SimpleDB::Client.new(region: 'us-west-1', stub_responses: true)
  end
  let(:domain_under_test) do
    od = OpenDelivery::Domain.new('us-west-1', 'spec/private.pem')
    od.instance_variable_set(:@sdb, simpledb)
    od
  end

  describe '#create' do
    context 'when passed a domain name' do
      it 'creates a new domain' do
        expect(simpledb).to receive(:create_domain).with(domain_name: domain_name)
        domain_under_test.create(domain_name)
      end
    end
  end

  describe '#destroy' do
    context 'when passed a domain name' do
      it 'deletes an existing domain' do
        expect(simpledb).to receive(:delete_domain).with(domain_name: domain_name)
        domain_under_test.destroy(domain_name)
      end
    end
  end

  describe '#load_domain' do
    context 'when given a valid json document' do
      it 'loads the json file entries into the domain' do
        expect(domain_under_test).to receive(:set_property)
          .with(domain_name, 'test', 'testFieldOne', 'testValueOne')
        expect(domain_under_test).to receive(:set_property)
          .with(domain_name, 'test', 'testFieldTwo', 'testValueTwoA')

        Tempfile.open('attributes') do |file|
          file.write('{  "test": { "testFieldOne" : "testValueOne", "testFieldTwo" : "testValueTwoA" }}')
          file.flush
          domain_under_test.load_domain(domain_name, file.path)
        end
      end
    end
  end

  describe '#destroy_item' do
    context 'when given a valid item' do
      it 'destroys the item' do
        expect(simpledb).to receive(:delete_attributes)
          .with(domain_name: domain_name, item_name: 'test_item')
        domain_under_test.destroy_item(domain_name, 'test_item')
      end
    end
  end

  describe '#get_property' do
    context 'when the property exists' do
      it 'returns the proper value for the specified key' do
        simpledb.stub_responses(
          :get_attributes,
          {
            attributes: [ { name: 'key', value: 'value'} ]
          }
        )

        expect(domain_under_test.get_property(domain_name, 'item', 'key')).to eql('value')
      end
    end

    context 'when the property or item does not exist' do
      it 'returns the nil' do
        expect(domain_under_test.get_property(domain_name, 'item', 'bad_key')).to be_nil
      end
    end
  end

  describe '#get_encrypted_property' do
    context 'when the property exists' do
      it 'returns the proper value for the specified key' do
        simpledb.stub_responses(
          :get_attributes,
          {
            attributes: [ { name: 'key', value: encrypted_hash } ]
          }
        )

        expect(domain_under_test.get_encrypted_property(domain_name, 'item', 'key')).to eql('encryptedvalue')
      end
    end
  end

  describe '#get_item_attributes_json' do
    context 'when the item exists' do
      it 'returns the attributes for the item as json' do
        simpledb.stub_responses(
          :get_attributes,
          {
            attributes: [
              { name: 'key', value: 'value' },
              { name: 'key2', value: 'value2'}
            ]
          }
        )
        expected_value = '[{"name":"key","value":"value"},{"name":"key2","value":"value2"}]'

        expect(domain_under_test.get_item_attributes_json(domain_name, 'item')).to eql(expected_value)
      end
    end

    context 'when the  item does not exist' do
      it 'returns nil' do
        expect(domain_under_test.get_item_attributes_json(domain_name, 'item')).to be_nil
      end
    end
  end

  describe '#set_property' do
    context 'when given a valid domain, item and properity' do
      it 'sets the appropriate attribute' do
        expect(simpledb).to receive(:put_attributes)
          .with(domain_name: domain_name, item_name: 'item', attributes: [
            {
              name: 'key',
              value: 'value',
              replace: true,
            }
          ])

        domain_under_test.set_property(domain_name, 'item', 'key', 'value')
      end
    end
  end

  describe '#set_encrypted_property' do
    context 'when given a valid domain, item and properity' do
      it 'sets the appropriate attribute' do
        expect(domain_under_test).to_not receive(:set_property)
          .with(domain_name, 'item', 'key', 'encryptedvalue')

        domain_under_test.set_encrypted_property(domain_name, 'item', 'key', 'encryptedvalue')
      end
    end
  end
end
