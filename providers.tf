terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # `~> 1.0` (>= 1.0, < 2.0), comme la branche upstream. L'ancienne borne haute
  # `<= 1.2.9` épinglait la version alors en usage chez LCDP et bloquait la montée
  # du repo terraform en 1.15.x (LDS-6058) ; elle ne traduisait aucune
  # incompatibilité du module.
  required_version = "~> 1.0"
}
