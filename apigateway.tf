resource "aws_apigatewayv2_vpc_link" "fiap_pagamento" {
  name               = "${var.app_name}-vpc-link"
  subnet_ids         = [data.aws_subnet.clustera.id, data.aws_subnet.clusterb.id, data.aws_subnet.clusterc.id]
  security_group_ids = []
  tags = {
    Name = "api-${var.app_name}"
  }
}

resource "aws_apigatewayv2_api" "fiap_pagamento" {
  name          = "${var.app_name}-api"
  description   = "API Gateway for fiap-pagamento"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "fiap_pagamento" {
  api_id     = aws_apigatewayv2_api.fiap_pagamento.id
  route_key  = "ANY /{proxy+}"
  target     = "integrations/${aws_apigatewayv2_integration.fiap_pagamento.id}"
  depends_on = [aws_apigatewayv2_integration.fiap_pagamento]
}

resource "aws_apigatewayv2_integration" "fiap_pagamento" {
  api_id           = aws_apigatewayv2_api.fiap_pagamento.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.fiap_pagamento.arn

  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.fiap_pagamento.id
  payload_format_version = "1.0"
  depends_on = [aws_apigatewayv2_vpc_link.fiap_pagamento,
    aws_apigatewayv2_api.fiap_pagamento,
  aws_lb_listener.fiap_pagamento]
}

resource "aws_apigatewayv2_stage" "fiap_pagamento" {
  api_id      = aws_apigatewayv2_api.fiap_pagamento.id
  name        = "$default"
  auto_deploy = true
  depends_on  = [aws_apigatewayv2_api.fiap_pagamento]
}

output "apigw_endpoint" {
  value       = aws_apigatewayv2_api.fiap_pagamento.api_endpoint
  description = "API Gateway Endpoint"
}
