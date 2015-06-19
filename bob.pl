srand(12345);
print int(1000*rand), $/ for 1..5;

use Math::Random;

Math::Random::random_set_seed_from_phrase('brad wanted me to test this');

for (1..10) {
    print scalar Math::Random::random_normal(undef, .5, 1), $/; 
}
