## Debug

```
be ruby sand.rb
```

## Conditions to be met
  
- `binding.pry if debug? :resolve`
3 раза просит одно и то же
- recursions.rb
- `Route::Execution.new(self, context).resolve`
отремонтировать finish - должен заходить в следующую функцию
- A.new.aa.bb.cc
  `step cc`
- Shouldn't go to the end:
    ```
    A.new.aa.bb.cc
    s
    n
    ```
- stack_explorer's up/down shouldn't break

    
### Maybe?
    
- (?) 10 Thread которые выполняют одно и тоже параллельно
rand должен быть верный на всех next - поймать кейс, где не тот начинается - чтобы проверит гипотизу, что действительно надо трекать thread

