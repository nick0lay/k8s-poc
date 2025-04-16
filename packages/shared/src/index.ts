/**
 * Common utility functions shared across applications
 */

/**
 * Format a timestamp into a readable date string
 */
export const formatDate = (date: Date): string => {
  return date.toISOString();
};

/**
 * Simple health check helper
 */
export const healthCheck = () => {
  return {
    status: 'ok',
    timestamp: formatDate(new Date())
  };
}; 