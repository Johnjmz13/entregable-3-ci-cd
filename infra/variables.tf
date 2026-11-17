# infra/variables.tf
variable "resource_group_name" {
  description = "Grupo de recursos existente donde se crean los ambientes (lo crea el script de preparación de Azure)"
  type        = string
  default     = "rg-calculadora-cicd"
}

variable "environment_name" {
  description = "Nombre del ambiente (staging o production)"
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment_name)
    error_message = "environment_name debe ser \"staging\" o \"production\"."
  }
}

variable "docker_image_uri" {
  description = "URI completa de la imagen Docker a desplegar (ej: docker.io/usuario/repo:tag)"
  type        = string
}

variable "app_version" {
  description = "Versión desplegada (en el pipeline es el SHA del commit). La app la expone en /health"
  type        = string
  default     = "manual"
}

variable "min_replicas" {
  description = "Réplicas mínimas. 0 = escala a cero sin tráfico (no cobra cómputo); 1 = siempre encendida, sin arranque en frío"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.min_replicas)
    error_message = "min_replicas debe ser 0 o 1."
  }
}
