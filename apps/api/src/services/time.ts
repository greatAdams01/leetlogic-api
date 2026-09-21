export const addDays = (date: Date, days: number) => new Date(date.getTime() + days * 86_400_000);
export const addHours = (date: Date, hours: number) => new Date(date.getTime() + hours * 3_600_000);

