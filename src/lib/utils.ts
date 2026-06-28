/**
 * Formatea un valor numérico como Pesos Chilenos (CLP) sin decimales.
 * Ejemplo: 15000 -> $15.000
 */
export function formatCLP(amount: number): string {
  return new Intl.NumberFormat('es-CL', {
    style: 'currency',
    currency: 'CLP',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}
