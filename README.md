# Facturama Ruby SDK

A comprehensive Ruby library for integrating with Facturama's Mexican electronic invoicing (CFDI) APIs - supporting both Web API for single-issuer operations and Multiemisor API for multi-issuer scenarios.

## 📋 Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Web API](#web-api-operations)
- [Multiemisor API](#multiemisor-api-operations)
  - [Authentication](#authentication)
  - [Certificate Management](#certificate-csd-management)
  - [Creating Invoices](#creating-invoices-cfdi)
  - [Invoice Operations](#invoice-operations)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Resources](#resources)

## Overview

Facturama provides two distinct API modes:

- **Web API**: Ideal for single businesses managing their own invoicing through Facturama's web platform
- **Multiemisor API**: Perfect for accounting software, ERPs, or multi-tenant applications that need to issue invoices on behalf of multiple businesses (RFCs)

## Installation

```bash
# Install via RubyGems
gem install facturama

# Or add to your Gemfile
gem 'facturama', '~> 0.0.2'

# For development, you only need rest-client
gem install rest-client
```

## Quick Start

### Web API
```ruby
require 'facturama'

# Initialize for single-issuer operations
facturama = Facturama::FacturamaApi.new(
  'your_username',
  'your_password',
  true  # true for sandbox, false for production
)

# Create a simple invoice
result = facturama.cfdis.create(cfdi_model)
puts "CFDI created with UUID: #{result['Complement']['TaxStamp']['Uuid']}"
```

### Multiemisor API
```ruby
require 'facturama'

# Initialize for multi-issuer operations
facturama = Facturama::FacturamaApiMulti.new(
  'your_username',
  'your_password',
  true  # true for sandbox, false for production
)

# Create an invoice for a specific RFC
result = facturama.cfdis.create3(cfdi_model)
puts "CFDI created with UUID: #{result['Complement']['TaxStamp']['Uuid']}"
```

## Web API Operations

The Web API provides comprehensive features for single-business operations:

- Create, retrieve, cancel CFDIs (3.3 and 4.0)
- Download XMLs, PDFs, and send by email
- Manage customer and product catalogs
- Upload logo and digital certificates
- Check account profile and subscription
- CRUD operations for:
  - Products
  - Customers
  - Branch offices
  - Series

*All operations are reflected in Facturama's web platform.*

Detailed examples: [Web API Wiki](https://github.com/Facturama/facturama-ruby-sdk/wiki/API-Web)

## Multiemisor API Operations

The Multiemisor API enables managing invoices for multiple businesses from a single account.

### Authentication

Both APIs use HTTP Basic Authentication:

```ruby
# Sandbox environment (for testing)
facturama = Facturama::FacturamaApiMulti.new(
  'prueba',          # Test username
  'pruebas2011',     # Test password
  true               # Development mode
)

# Production environment
facturama = Facturama::FacturamaApiMulti.new(
  'your_username',
  'your_password',
  false              # Production mode
)
```

**API Endpoints:**
- Sandbox: `https://apisandbox.facturama.mx`
- Production: `https://api.facturama.mx`

### Certificate (CSD) Management

Before issuing invoices for a specific RFC, you must upload the corresponding digital certificate.

#### Upload a Certificate
```ruby
# Read and encode certificate files
cert_content = Base64.encode64(File.read('path/to/certificate.cer'))
key_content = Base64.encode64(File.read('path/to/private_key.key'))

# Create CSD model
csd = {
  Rfc: "EKU9003173C9",
  Certificate: cert_content.delete("\n"),     # Remove line breaks
  PrivateKey: key_content.delete("\n"),       # Remove line breaks
  PrivateKeyPassword: "your_private_key_password"
}

# Upload the certificate
facturama.csds.create(csd)
```

#### List All Certificates
```ruby
certificates = facturama.csds.list
puts "Total certificates: #{certificates.count}"

certificates.each do |cert|
  puts "RFC: #{cert['Rfc']}, Valid until: #{cert['ValidTo']}"
end
```

#### Retrieve, Update, or Delete
```ruby
# Get specific certificate
certificate = facturama.csds.retrieve("EKU9003173C9")

# Update certificate
facturama.csds.update(updated_csd, "EKU9003173C9")

# Delete certificate
facturama.csds.remove("EKU9003173C9")
```

### Creating Invoices (CFDI)

The Multiemisor API supports both CFDI 3.3 and 4.0. The key requirement is the `Issuer` section.

#### CFDI 4.0 Example
```ruby
cfdi = {
  "Serie": "R",
  "Currency": "MXN",
  "ExpeditionPlace": "78140",
  "CfdiType": "I",              # I = Income
  "PaymentForm": "03",          # Electronic transfer
  "PaymentMethod": "PUE",       # Single payment
  
  # REQUIRED: Issuer information
  "Issuer": {
    "FiscalRegime": "601",
    "Rfc": "EKU9003173C9",
    "Name": "ESCUELA KEMPER URGATE"
  },
  
  "Receiver": {
    "Rfc": "URE180429TM6",
    "Name": "UNIVERSIDAD ROBOTICA ESPAÑOLA",
    "CfdiUse": "G03",
    "FiscalRegime": "601",
    "TaxZipCode": "65000"
  },
  
  "Items": [
    {
      "ProductCode": "10101504",
      "Description": "Estudios de laboratorio",
      "Unit": "NO APLICA",
      "UnitCode": "MTS",
      "UnitPrice": 100.0,
      "Quantity": 2.0,
      "Subtotal": 200.0,
      "TaxObject": "02",
      "Taxes": [
        {
          "Total": 32.0,
          "Name": "IVA",
          "Base": 200.0,
          "Rate": 0.16,
          "IsRetention": false
        }
      ],
      "Total": 232.0
    }
  ]
}

# Create CFDI 4.0
result = facturama.cfdis.create3(cfdi)
puts "UUID: #{result['Complement']['TaxStamp']['Uuid']}"
```

#### CFDI 3.3
For CFDI 3.3, use the `create` method instead of `create3`:
```ruby
result = facturama.cfdis.create(cfdi_33_model)
```

### Invoice Operations

#### List Invoices
```ruby
# Search by keyword
invoices = facturama.cfdis.list_by_keyword("UNIVERSIDAD", "all")

# Search by RFC
invoices = facturama.cfdis.list_by_rfc("EKU9003173C9", "issued", "Income")

# Advanced search with filters
invoices = facturama.cfdis.list(
  keyword: "ROBOTICA",
  date_start: "2024-01-01",
  date_end: "2024-12-31",
  status: "all",      # all, active, canceled
  type: "issued"      # issued, received
)
```

#### Download Files
```ruby
cfdi_id = "5d5e4066-8c2a-4b4d-8442-example"

# Download files
facturama.cfdis.save_pdf("invoice.pdf", cfdi_id)
facturama.cfdis.save_xml("invoice.xml", cfdi_id)
facturama.cfdis.save_html("invoice.html", cfdi_id)

# Send by email
facturama.cfdis.send_by_mail(
  cfdi_id,
  "customer@example.com",
  "Your invoice is ready"
)
```

#### Cancel Invoice
```ruby
# Cancel with motive (required for CFDI 4.0)
# Motives: 01=Errors, 02=No longer needed, 03=Wrong operation, 04=Replaced
facturama.cfdis.remove(cfdi_id, "02", nil)

# Cancel with replacement UUID (motive 04)
facturama.cfdis.remove(cfdi_id, "04", "replacement-uuid")
```

## Error Handling

The SDK uses `FacturamaException` for API errors:

```ruby
begin
  result = facturama.cfdis.create3(cfdi)
rescue FacturamaException => e
  puts "Error: #{e.message}"
  
  # Access detailed validation errors
  if e.details && e.details['ModelState']
    e.details['ModelState'].each do |field, errors|
      puts "Field '#{field}': #{errors.join(', ')}"
    end
  end
end
```

## Complete Working Example

```ruby
require 'facturama'
require 'base64'

# Initialize Multiemisor client
facturama = Facturama::FacturamaApiMulti.new('prueba', 'pruebas2011', true)

# Step 1: Upload certificate (one-time setup per RFC)
begin
  cert_file = File.read('certificates/EKU9003173C9.cer')
  key_file = File.read('certificates/EKU9003173C9.key')
  
  csd = {
    Rfc: "EKU9003173C9",
    Certificate: Base64.encode64(cert_file).delete("\n"),
    PrivateKey: Base64.encode64(key_file).delete("\n"),
    PrivateKeyPassword: "12345678a"
  }
  
  facturama.csds.create(csd)
  puts "Certificate uploaded successfully"
rescue FacturamaException => e
  puts "Certificate error: #{e.message}"
end

# Step 2: Create invoice
cfdi = {
  "Serie": "A",
  "Currency": "MXN",
  "ExpeditionPlace": "78140",
  "CfdiType": "I",
  "PaymentForm": "03",
  "PaymentMethod": "PUE",
  "Issuer": {
    "FiscalRegime": "601",
    "Rfc": "EKU9003173C9",
    "Name": "ESCUELA KEMPER URGATE"
  },
  "Receiver": {
    "Rfc": "XAXX010101000",
    "Name": "PUBLICO EN GENERAL",
    "CfdiUse": "S01",
    "FiscalRegime": "616",
    "TaxZipCode": "78000"
  },
  "Items": [
    {
      "ProductCode": "01010101",
      "Description": "Producto de ejemplo",
      "Unit": "Pieza",
      "UnitCode": "H87",
      "UnitPrice": 100.0,
      "Quantity": 1.0,
      "Subtotal": 100.0,
      "TaxObject": "02",
      "Taxes": [
        {
          "Total": 16.0,
          "Name": "IVA",
          "Base": 100.0,
          "Rate": 0.16,
          "IsRetention": false
        }
      ],
      "Total": 116.0
    }
  ]
}

# Create the invoice
result = facturama.cfdis.create3(cfdi)
cfdi_id = result['Id']
uuid = result['Complement']['TaxStamp']['Uuid']

puts "Invoice created successfully!"
puts "ID: #{cfdi_id}"
puts "UUID: #{uuid}"

# Step 3: Download files
facturama.cfdis.save_pdf("invoice_#{uuid}.pdf", cfdi_id)
facturama.cfdis.save_xml("invoice_#{uuid}.xml", cfdi_id)

puts "Files downloaded successfully"
```

## Best Practices

1. **Certificate Security**: Store certificates and private keys securely. Never commit them to version control.

2. **Environment Management**: Always test thoroughly in sandbox before production deployment.

3. **Error Handling**: Implement comprehensive error handling for all API operations.

4. **UUID Tracking**: Always store the UUID returned after creating invoices for future reference.

5. **Rate Limiting**: Implement appropriate throttling to respect API rate limits.

6. **File Storage**: Maintain copies of all generated XML and PDF files for compliance.

## Resources

- [Official API Documentation](https://apisandbox.facturama.mx/guias)
- [Web API Examples](https://github.com/Facturama/facturama-ruby-sdk/wiki/API-Web)
- [Multiemisor API Examples](https://github.com/Facturama/facturama-ruby-sdk/wiki/API-Multiemisor)
- [SAT Catalog Codes](https://www.sat.gob.mx/consultas/35025/conoce-los-catalogos-que-se-utilizan-en-la-factura-electronica)
- [CFDI 4.0 Specification](https://www.sat.gob.mx/consultas/92764/comprobante-fiscal-digital-por-internet-(cfdi))

## Contributing

We welcome contributions! Just fork the project on GitHub, create a topic branch, write some code, and add tests for your new code.

## License

MIT License - see LICENSE file for details.