import { apiRequestExtended } from '../apiRequest';
import { User } from '../types/user';

export const getAllUsersExtended = async (): Promise<User[]> => {
  return apiRequestExtended<User[]>('/api/users', {
    method: 'GET',
    requiresAuth: false,
  });
};


