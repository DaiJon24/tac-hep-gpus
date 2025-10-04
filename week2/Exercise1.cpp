#include <iostream>           

void swap(int &a, int &b) {
    int temp = a;
    a = b;
    b = temp;
}

int main() {
   int a[10]={1,2,3,4,5,6,7,8,9,10};
   int b[10]={11,12,13,14,15,16,17,18,19,20};

   for (int i = 0; i < 10; i++) {
       swap(a[i], b[i]);
   }

   std::cout << "Array a: ";
   for (int i = 0; i < 10; i++) {
       std::cout << a[i] << " ";
   }
    std::cout << std::endl;

   std::cout << "Array b: ";
   for (int i = 0; i < 10; i++) {
       std::cout << b[i] << " ";
   }
   std::cout << std::endl;

   return 0;
}