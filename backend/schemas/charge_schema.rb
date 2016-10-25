module ChargeSchema
  REQUEST = {
    type: :object,
    required: ['amount', 'card'],
    properties: {
      amount: { type: :number, minimum: 0 },
      card: {
        type: :object,
        required: ['holder', 'number', 'expiration_month', 'expiration_year', 'cvv'],
        properties: {
          holder: { type: :string },
          number: { type: :string, minLength: 16, maxLength: 16, pattern: /\d{16}/ },
          expiration_month: { type: :number, minimum: 1, maximum: 12 },
          expiration_year: { type: :number, minimum: Date.today.year },
          cvv: { type: :string, minimum: 3, maximum: 3, pattern: /\d{3}/ }
        }
      },
      intermediaries: {
        type: :array,
        items: [
          {
            type: :object,
            properties: {
              fee: { type: :number, minimum: 0 },
              flat: { type: :number, minimum: 0 },
              description: { type: :string }
            }
          }
        ]
      }
    }
  }

  RESPONSE = {
    type: 'object',
    required: ['id', 'amount', 'card_id', 'intermediaries'],
    properties: {
      id: { type: :string },
      amount: { type: :number },
      card_id: { type: :string },
      intermediaries: {
        type: :array,
        items: [
          {
            type: :object,
            properties: {
              fee: { type: :number, minimum: 0 },
              flat: { type: :number, minimum: 0 },
              description: { type: :string }
            }
          }
        ]
      }
    }
  }
end
