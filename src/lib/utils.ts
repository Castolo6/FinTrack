/**
 * Formatea un valor numérico según la moneda seleccionada.
 * Por defecto usa Pesos Chilenos (CLP) si no se especifica otra.
 */
export function formatCLP(amount: number, currency: string = 'CLP'): string {
  const locale = currency === 'CLP' 
    ? 'es-CL' 
    : currency === 'EUR' 
      ? 'de-DE' 
      : currency === 'MXN' || currency === 'COP' || currency === 'ARS'
        ? 'es-MX'
        : 'en-US';

  const decimalDigits = (currency === 'CLP' || currency === 'COP') ? 0 : 2;

  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: decimalDigits,
    maximumFractionDigits: decimalDigits,
  }).format(amount);
}
