require 'spec_helper'
require 'date'

describe RubyGPG2::ColonOutput do
  context 'equality' do
    it 'is equal if it has identical records' do
      first = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC::::::23::0:")
      ])
      second = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC::::::23::0:")
      ])

      expect(first).to(eq(second))
    end

    it 'is not equal if it has different records' do
      first = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC::::::23::0:")
      ])
      second = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:71BF470703C2F2B0:" +
                  "1462791132:::u:::scESC::::::23::0:")
      ])

      expect(first).not_to(eq(second))
    end
  end

  context 'public key extraction' do
    it 'finds a single public key' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC::::::23::0:")
      ])

      expect(output.public_keys).to(eq([
          RubyGPG2::Key.new(
              type: :public,
              validity: :ultimate,
              length: 2048,
              algorithm: :rsa_encrypt_or_sign,
              id: '1A16916844CE9D82',
              creation_date: DateTime.strptime('1333003000', '%s'),
              owner_trust: :ultimate,
              capabilities: [
                  :sign,
                  :certify,
                  :primary_encrypt,
                  :primary_sign,
                  :primary_certify
              ],
              compliance_modes: [:de_vs],
              origin: '0'
          )
      ]))
    end

    it 'finds multiple public keys' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC::::::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:71BF470703C2F2B0:" +
                  "1462791132:::u:::scESC::::::23::0:")
      ])

      expect(output.public_keys).to(eq([
          RubyGPG2::Key.new(
              type: :public,
              validity: :ultimate,
              length: 2048,
              algorithm: :rsa_encrypt_or_sign,
              id: '1A16916844CE9D82',
              creation_date: DateTime.strptime('1333003000', '%s'),
              owner_trust: :ultimate,
              capabilities: [
                  :sign,
                  :certify,
                  :primary_encrypt,
                  :primary_sign,
                  :primary_certify
              ],
              compliance_modes: [:de_vs],
              origin: '0'
          ),
          RubyGPG2::Key.new(
              type: :public,
              validity: :ultimate,
              length: 2048,
              algorithm: :rsa_encrypt_or_sign,
              id: '71BF470703C2F2B0',
              creation_date: DateTime.strptime('1462791132', '%s'),
              owner_trust: :ultimate,
              capabilities: [
                  :sign,
                  :certify,
                  :primary_encrypt,
                  :primary_sign,
                  :primary_certify
              ],
              compliance_modes: [:de_vs],
              origin: '0'
          )
      ]))
    end

    it 'includes fingerprints when available' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC::::::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "fpr:::::::::41D2606F66C3FF28874362B61A16916844CE9D82:"),
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:71BF470703C2F2B0:" +
                  "1462791132:::u:::scESC::::::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "fpr:::::::::EFF5E293ECCDED05F904930BE95EE38A51E0DE13:"),
      ])

      public_keys = output.public_keys

      expect(public_keys[0].id).to(eq('1A16916844CE9D82'))
      expect(public_keys[0].fingerprint)
          .to(eq('41D2606F66C3FF28874362B61A16916844CE9D82'))
      expect(public_keys[1].id).to(eq('71BF470703C2F2B0'))
      expect(public_keys[1].fingerprint)
          .to(eq('EFF5E293ECCDED05F904930BE95EE38A51E0DE13'))
    end

    it 'includes user IDs when available' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC::::::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "uid:u::::1333003000::" +
                  "6D9560936837E5AC5007524183B9F354E4F5308C::" +
                  "Toby Clemson <tobyclemson@gmail.com>::::::::::0:"),
          RubyGPG2::ColonRecord.parse(
              "pub:u:2048:1:71BF470703C2F2B0:" +
                  "1462791132:::u:::scESC::::::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "uid:-::::1469712635::" +
                  "F3081A9B1E766B0C4C9D508A0179CCCD574BC170::" +
                  "Jade Morris <jade.morris@example.com>::::::::::0:"),
          RubyGPG2::ColonRecord.parse(
              "uid:-::::1469712635::" +
                  "54A6A77CC1F8E82FF31188580B4CCA800364DE92::" +
                  "Jade Morris (Personal) <jade@morris.com>::::::::::0:"),
      ])

      public_keys = output.public_keys

      key_1 = public_keys[0]
      key_1_expected_user_id_1 = RubyGPG2::UserID.new(
          name: 'Toby Clemson',
          email: 'tobyclemson@gmail.com',
          validity: :ultimate,
          creation_date: DateTime.strptime('1333003000', '%s'),
          hash: '6D9560936837E5AC5007524183B9F354E4F5308C',
          origin: '0')

      key_2 = public_keys[1]
      key_2_expected_user_id_1 = RubyGPG2::UserID.new(
          name: 'Jade Morris',
          email: 'jade.morris@example.com',
          validity: :unknown,
          creation_date: DateTime.strptime('1469712635', '%s'),
          hash: 'F3081A9B1E766B0C4C9D508A0179CCCD574BC170',
          origin: '0')
      key_2_expected_user_id_2 = RubyGPG2::UserID.new(
          name: 'Jade Morris',
          comment: 'Personal',
          email: 'jade@morris.com',
          validity: :unknown,
          creation_date: DateTime.strptime('1469712635', '%s'),
          hash: '54A6A77CC1F8E82FF31188580B4CCA800364DE92',
          origin: '0')

      expect(key_1.id).to(eq('1A16916844CE9D82'))
      expect(key_1.primary_user_id).to(eq(key_1_expected_user_id_1))
      expect(key_1.user_ids).to(eq([key_1_expected_user_id_1]))

      expect(key_2.id).to(eq('71BF470703C2F2B0'))
      expect(key_2.primary_user_id).to(eq(key_2_expected_user_id_1))
      expect(key_2.user_ids).to(eq([
          key_2_expected_user_id_1,
          key_2_expected_user_id_2
      ]))
    end
  end

  context 'secret key extraction' do
    it 'finds a single secret key' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "sec:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC:::+:::23::0:")
      ])

      expect(output.secret_keys).to(eq([
          RubyGPG2::Key.new(
              type: :secret,
              validity: :ultimate,
              length: 2048,
              algorithm: :rsa_encrypt_or_sign,
              id: '1A16916844CE9D82',
              creation_date: DateTime.strptime('1333003000', '%s'),
              owner_trust: :ultimate,
              capabilities: [
                  :sign,
                  :certify,
                  :primary_encrypt,
                  :primary_sign,
                  :primary_certify
              ],
              serial_number: '+',
              compliance_modes: [:de_vs],
              origin: '0'
          )
      ]))
    end

    it 'finds multiple secret keys' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "sec:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC:::+:::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "sec:u:2048:1:71BF470703C2F2B0:" +
                  "1462791132:::u:::scESC:::+:::23::0:")
      ])

      expect(output.secret_keys).to(eq([
          RubyGPG2::Key.new(
              type: :secret,
              validity: :ultimate,
              length: 2048,
              algorithm: :rsa_encrypt_or_sign,
              id: '1A16916844CE9D82',
              creation_date: DateTime.strptime('1333003000', '%s'),
              owner_trust: :ultimate,
              capabilities: [
                  :sign,
                  :certify,
                  :primary_encrypt,
                  :primary_sign,
                  :primary_certify
              ],
              serial_number: '+',
              compliance_modes: [:de_vs],
              origin: '0'
          ),
          RubyGPG2::Key.new(
              type: :secret,
              validity: :ultimate,
              length: 2048,
              algorithm: :rsa_encrypt_or_sign,
              id: '71BF470703C2F2B0',
              creation_date: DateTime.strptime('1462791132', '%s'),
              owner_trust: :ultimate,
              capabilities: [
                  :sign,
                  :certify,
                  :primary_encrypt,
                  :primary_sign,
                  :primary_certify
              ],
              serial_number: '+',
              compliance_modes: [:de_vs],
              origin: '0'
          )
      ]))
    end

    it 'includes fingerprints when available' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "sec:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC:::+:::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "fpr:::::::::41D2606F66C3FF28874362B61A16916844CE9D82:"),
          RubyGPG2::ColonRecord.parse(
              "sec:u:2048:1:71BF470703C2F2B0:" +
                  "1462791132:::u:::scESC:::+:::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "fpr:::::::::EFF5E293ECCDED05F904930BE95EE38A51E0DE13:"),
      ])

      secret_keys = output.secret_keys

      expect(secret_keys[0].id).to(eq('1A16916844CE9D82'))
      expect(secret_keys[0].fingerprint)
          .to(eq('41D2606F66C3FF28874362B61A16916844CE9D82'))
      expect(secret_keys[1].id).to(eq('71BF470703C2F2B0'))
      expect(secret_keys[1].fingerprint)
          .to(eq('EFF5E293ECCDED05F904930BE95EE38A51E0DE13'))
    end

    it 'includes user IDs when available' do
      output = RubyGPG2::ColonOutput.new([
          RubyGPG2::ColonRecord.parse(
              "sec:u:2048:1:1A16916844CE9D82:" +
                  "1333003000:::u:::scESC:::+:::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "uid:u::::1333003000::" +
                  "6D9560936837E5AC5007524183B9F354E4F5308C::" +
                  "Toby Clemson <tobyclemson@gmail.com>::::::::::0:"),
          RubyGPG2::ColonRecord.parse(
              "sec:u:2048:1:71BF470703C2F2B0:" +
                  "1462791132:::u:::scESC:::+:::23::0:"),
          RubyGPG2::ColonRecord.parse(
              "uid:-::::1469712635::" +
                  "F3081A9B1E766B0C4C9D508A0179CCCD574BC170::" +
                  "Jade Morris <jade.morris@example.com>::::::::::0:"),
          RubyGPG2::ColonRecord.parse(
              "uid:-::::1469712635::" +
                  "54A6A77CC1F8E82FF31188580B4CCA800364DE92::" +
                  "Jade Morris (Personal) <jade@morris.com>::::::::::0:"),
      ])

      secret_keys = output.secret_keys

      key_1 = secret_keys[0]
      key_1_expected_user_id_1 = RubyGPG2::UserID.new(
          name: 'Toby Clemson',
          email: 'tobyclemson@gmail.com',
          validity: :ultimate,
          creation_date: DateTime.strptime('1333003000', '%s'),
          hash: '6D9560936837E5AC5007524183B9F354E4F5308C',
          origin: '0')

      key_2 = secret_keys[1]
      key_2_expected_user_id_1 = RubyGPG2::UserID.new(
          name: 'Jade Morris',
          email: 'jade.morris@example.com',
          validity: :unknown,
          creation_date: DateTime.strptime('1469712635', '%s'),
          hash: 'F3081A9B1E766B0C4C9D508A0179CCCD574BC170',
          origin: '0')
      key_2_expected_user_id_2 = RubyGPG2::UserID.new(
          name: 'Jade Morris',
          comment: 'Personal',
          email: 'jade@morris.com',
          validity: :unknown,
          creation_date: DateTime.strptime('1469712635', '%s'),
          hash: '54A6A77CC1F8E82FF31188580B4CCA800364DE92',
          origin: '0')

      expect(key_1.id).to(eq('1A16916844CE9D82'))
      expect(key_1.primary_user_id).to(eq(key_1_expected_user_id_1))
      expect(key_1.user_ids).to(eq([key_1_expected_user_id_1]))

      expect(key_2.id).to(eq('71BF470703C2F2B0'))
      expect(key_2.primary_user_id).to(eq(key_2_expected_user_id_1))
      expect(key_2.user_ids).to(eq([
          key_2_expected_user_id_1,
          key_2_expected_user_id_2
      ]))
    end
  end
end
