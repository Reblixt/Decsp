export function monthsUntil(timestamp: number): number {
  const now = new Date(); // Dagens datum
  const futureDate = new Date(timestamp * 1000); // Konvertera tidsstämpeln till millisekunder

  const yearsDifference = futureDate.getFullYear() - now.getFullYear();
  const monthsDifference = futureDate.getMonth() - now.getMonth();

  // Total skillnad i månader
  return yearsDifference * 12 + monthsDifference;
}
