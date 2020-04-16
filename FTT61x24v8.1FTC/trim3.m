function str2 = trim1(str,car)
%---function str = trim1(str)
%---Fonction qui sert à couper une string
%---Garde tous les caractères dans 'str' avant le dernier caractère contenu dans 'car'
%---Utile pour saisir le PATH
%---Retourne [] dans le cas où le résultat est vide

i = length(str);
while i > 0 & str(i) ~= car
   i = i - 1;
end
if i == 0 | i == length(str)
   str2 = '';
else
   str2 = str(1:i-1);
end
   